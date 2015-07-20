@CLASS
auth2

@USE
common/Lib.p
common/auth.p

@BASE
auth

@htmlFormLogon[hParam]
$hParam[^hash::create[$hParam]]
^untaint[html]{
	<div id="IDLoginForm">

	^if(def $form:[auth.logon]){
# 		<div>Забыли пароль?<br />Воспользуйтесь <a href="/_auth_forgot.html">данной формой</a> для того чтобы установить себе новый пароль.</div>
		<div>Неверное имя пользователя или пароль</div>
	}
	<form
		method="post"
		^if(def $hParam.target_url){
			action="$hParam.target_url"
		}
	>
		<input type="hidden" name="auth.logon" value="do" />
		<input type="hidden" name="auth.persistent" value="1" />
# 		<label for="IDAuthName">Электронная почта</label>
		<input type="text" placeholder="Электронная почта" id="IDAuthName" name="auth.name" 
		value="^if(def $logon_data.[auth.logon]){$logon_data.[auth.name]}{$last_name}" />
		
# 		<label for="IDAuthPassword">Пароль</label>
		<input type="password" placeholder="Пароль" id="IDAuthPassword" name="auth.passwd" description="Пароль" />
		<div class="float">
# 		<input type="checkbox" name="auth.persistent" value="1"^if($is_persistent){ checked="checked"} id="IDAuthPersistent"/>
# 		<label for="IDAuthPersistent">Узнавать всегда</label>
		<input type="submit" name="action2" value="^if(def $hParam.action_name){$hParam.action_name}{Войти в Куда сколько}" />
</div>
	</form>
	</div>
}

@htmlFormLogonProcess[hParams][_hParams]
$_hParams[^hash::create[$hParams]]
$is_show_form(1)

^if(def $form:do){

		^try{

			^logon[
				$form:fields
				$.[auth.logon][do]
			]
# 			<p>Пользователь успешно зарегистрирован.</p>
			$is_show_form(0)
			
			$response:location[$MAIN:MONEY.SERVER_HOST/]
		}{
			^if($exception.type eq 'auth.insert' ||
				$exception.type eq 'auth.logon'){
				$exception.handled(1)
			}
			<div>^printReadableError[^decodeError[]]</div>
# 			$errors[^decodeError[]]
# 			<p>$exception.type При регистрации нового пользователя возникли следующие проблемы: ^errors.menu{$errors.name = $errors.code}[, ].</p>
		}
}

^if($is_show_form){
	^rem{ *** если надо показываем форму регистрации/изменения параметров *** }
	^htmlFormProfile[
		$.fields[$form:fields]
		$.target_url[$_hParams.target_url]
	]
}

###########################################################################
@htmlFormProfile[hParams][_hParams]
^self.setExpireHeaders[]
$_hParams[^hash::create[$hParams]]
<div id="IDSignupForm">
<form
	method="post"
	^if(def $_hParams.target_url){
		action="$_hParams.target_url"
	}
>
^untaint[html]{
	$_hParams.addon
	<input type="hidden" name="do" value="^if(def $_hParams.do){$_hParams.do}{register}" />

# 	Электронная почта <br />
	<input type="text" placeholder="Электронная почта" name="auth.name" value="^if(def $_hParams.fields.[auth.name]){$_hParams.fields.[auth.name]}{$user.name}" />
# 	* E-mail:<br />
# 	<input type="text" name="auth.email" value="^if(def $_hParams.fields.[auth.email]){$_hParams.fields.[auth.email]}{$user.email}"/><br />
# 	^if(!$is_logon){* }Пароль:<br />
	<input type="password" placeholder="Пароль" name="auth.passwd" />
# 	^if(!$is_logon){* }Подтверждение пароля:<br />
# 	<input type="password" name="auth.passwd_confirm" /><br />

	<input type="submit" name="action2" value="^if(def $_hParams.action_name){$_hParams.action_name}{^if($is_logon){Сохранить}{Зарегистрироваться}}" />
	$_hParams.post_addon
}
</form>
</div>
#end @htmlFormProfile[]



###########################################################################
# checking before insert new user
@beforeInsert[hUser]
$result[]
^if(!def $hUser.[auth.name]){
	^self.addErrorCode[login_empty]
}
^if(!def $hUser.[auth.passwd]){
	^self.addErrorCode[password_empty]
}
# ^if(
# 	def $hUser.[auth.passwd]
#  	&& $hUser.[auth.passwd] ne $hUser.[auth.passwd_confirm]
# ){
# 	^self.addErrorCode[password_confirmation_error]
# }

^self.checkEmail[$hUser.[auth.name]]

^if(
	def $hUser.[auth.name]
	&& ^self.getUserCount[
		$.name[$hUser.[auth.name]]
	]
){
	^self.addErrorCode[login_exist]
}
#end @beforeInsert[]



###########################################################################
# checkings before update user
@beforeUpdate[hUser]
$result[]
^if(!$is_logon){
	^self.addErrorCode[not_logged]
}
^if(!def $hUser.[auth.name]){
	^self.addErrorCode[login_empty]
}
^if(
	def $hUser.[auth.passwd]
# 	&& $hUser.[auth.passwd] ne $hUser.[auth.passwd_confirm]
){
	^self.addErrorCode[password_confirmation_error]
}
^if(
	def $hUser.[auth.name]
	&& $hUser.[auth.name] ne $user.name
	&& ^self.getUserCount[
		$.name[$hUser.[auth.name]]
		$.user_id($user.user_id)
	]
){
	^self.addErrorCode[login_exist]
}

^self.checkEmail[$hUser.[auth.name]]
#end @beforeUpdate[]



###########################################################################
# изменение параметров пользователя
@updateUser[user_data][_type;_event_type;_comment;_user]
$_type[auth.update]
^self.initStatus(0)
^try{
	^self.beforeUpdate[$user_data]
	
	^if($status){
		^throw[$_type;errors]
	}
	
	$_event_type($EVENT.update_user)
	$_comment[]
	^if($user_data.[auth.name] ne $user.name
		&& ^self.isEmail[$user_data.[auth.name]]
	){
		^_event_type.inc($EVENT.change_name)
		$_comment[${_comment}prev_name: $user.name ]
	}
	^if(def $user_data.[auth.passwd]){
		^_event_type.inc($EVENT.change_password)
	}
# 	^if(
# 		$user_data.[auth.email] ne $user.email
# 		&& ^self.isEmail[$user_data.[auth.email]]
# 	){
# 		^_event_type.inc($EVENT.change_email)
# 		$_comment[${_comment}prev_email: $user.email ]
# 	}
	$_user[
		$.user_id($user.user_id)
		$.name[$user_data.[auth.name]]
# 		$.email[$user_data.[auth.email]]
		$.event_type[$user.event_type]
	]

	^oSql.void{
		UPDATE
			auser
		SET
# 			name = '$user_data.[auth.name]'
			^if(^isEmail[$user_data.[auth.name]]){name = '$user_data.[auth.name]'}
			^if(def $user_data.description){, description = /**description**/'$user_data.description'}
			^if(def $user_data.[auth.passwd]){, passwd = '^cryptPassword[$user_data.[auth.passwd]]'}
			^if(def $user_data.[auth.rights]){, rights = $user_data.[auth.rights]}
			^additional_fields.menu{
				^if(def $additional_fields.fields.update && def $additional_fields.fields.field){
					, $additional_fields.fields.update = '$user_data.[$additional_fields.fields.field]'
				}
			}
		WHERE
			auser_id = $user.user_id
	}
	^if(def $user_data.[auth.passwd]){
		^self.clearUserSessions[$user.user_id;$session.session_id]
	}

	^self.postUpdate[$user.user_id;$user_data]

	^self.logEvent[$_user;$_event_type;$status;$_comment]
}{
	$exception.handled(1)
	
	^if($exception.type ne $_type){
		^self.addErrorCode[unknown]
	}
	^self.appendError[$_type;$status]
	^self.logEvent[$_user;$_event_type;$status;$_comment]
	^throw[$_type^if($exception.type ne $_type){.$exception.type};$exception.source;$exception.comment]
}
#end @updateUser[]



###########################################################################
# добавление нового пользователя
@insertUser[user_data][_type]
$_type[auth.insert]
^self.initStatus(0)
^try{
	^self.beforeInsert[$user_data]

	^if($status){
		^throw[$_type;errors]
	}
	
	^oSql.void{INSERT INTO auser (
		auser_type_id,
		name,
# 		email,
		passwd,
		dt_register,
		event_type
		^if(def $user_data.[auth.rights]){, rights}
		^additional_fields.menu{
			^if(def $additional_fields.fields.update && def $additional_fields.fields.field){
				, $additional_fields.fields.update
			}
		}
	) VALUES (
		$USER_ID,
		'$user_data.[auth.name]',
# 		'$user_data.[auth.email]',
		'^self.cryptPassword[$user_data.[auth.passwd]]',
		^oSql.now[],
		$new_user_event_type
		^if(def $user_data.[auth.rights]){, $user_data.[auth.rights]}
		^additional_fields.menu{
			^if(def $additional_fields.fields.update && def $additional_fields.fields.field){
				, '$user_data.[$additional_fields.fields.field]'
			}
		}
	)}

	$new_user[
		$.user_id(^oSql.last_insert_id[auser])
		$.name[$user_data.[auth.name]]
# 		$.email[$user_data.[auth.email]]
		$.rights[$user_data.rights]
		$.event_type[$EVENT.insert_user]
	]

	^try{
		^rem{ *** загружаем полный список групп *** }
		^self.getGroups[]
    	
		^rem{ *** включаем вновь добавленного пользователя в группы, у которых установлен флаг is_default *** }
		^groups.menu{
			^if($groups.is_default){
				^oSql.void{INSERT INTO auser_to_auser (
					auser_id,
					parent_id
				) VALUES (
					$new_user.user_id,
					$groups.group_id
				)}
			}
		}
	}{
		^rem{ *** если не удалось добавить пользователя в группы - ну и хрен с ними (пока) *** }
		$exception.handled(1)
	}
	^self.postInsert[$new_user.user_id;$user_data]

	^self.logEvent[$new_user;$EVENT.insert_user;$status]
}{
	$exception.handled(1)
	^if($exception.type ne $_type){
		^addErrorCode[unknown]
	}
	^self.appendError[$_type;$status]
	^self.logEvent[$new_user;$EVENT.insert_user;$status]
	^throw[$_type^if($exception.type ne $_type){.$exception.type};$exception.source;$exception.comment]
}
#end @insertUser[]


@postInsert[iUserId;hUser]
^dbo:initUser(^iUserId.int(0))

@htmlFormRegister[hParams][_hParams]
$_hParams[^hash::create[$hParams]]
<h2>^if($is_logon){Изменение параметров}{Регистрация}</h2>
$is_show_form(1)

^if(def $form:do){
	^if($is_logon){
		^try{
			^rem{ *** сохраняем параметры существующего пользователя *** }
			^updateUser[$form:fields]
			<p>Параметры пользователя сохранены.</p>
			$is_show_form(0)
		}{
			$exception.handled(1)
			^printReadableError[^decodeError[]]
# 			$errors[^decodeError[]]
# 			<p>При сохранении новых параметров пользователя возникли следующие проблемы: ^errors.menu{$errors.name}[, ].</p>
		}
	}{
		^try{
			^rem{ *** регистрация нового пользователя *** }
			^insertUser[$form:fields]

			^rem{ *** если регистрация прошла успешно - логиним пользователя *** }
			^logon[
				$form:fields
				$.[auth.logon][do]
				$.[auth.persistent](1)
			]
# 			<p>Пользователь успешно зарегистрирован.</p>
			$is_show_form(0)
			
			$response:location[$MAIN:MONEY.SERVER_HOST/]
		}{
			^if($exception.type eq 'auth.insert' ||
				$exception.type eq 'auth.logon'){
				$exception.handled(1)
			}
			<div>^printReadableError[^decodeError[]]</div>
# 			$errors[^decodeError[]]
# 			<p>$exception.type При регистрации нового пользователя возникли следующие проблемы: ^errors.menu{$errors.name = $errors.code}[, ].</p>
		}
	}
}

^if($is_show_form){
	^rem{ *** если надо показываем форму регистрации/изменения параметров *** }
	^htmlFormProfile[
		$.fields[$form:fields]
		$.target_url[$_hParams.target_url]
	]
}


@printReadableError[tErrors][hLabels]
$hLabels[
	$.not_logged[Вы не вошли в систему]
	$.login_empty[Пожалуйста, укажите адрес электронной почты]
	$.login_exist[Этот электронный адрес уже используется другим пользователем]
	$.password_empty[Пожалуйста, введите пароль]
	$.password_confirmation_error[password_confirmation_error]
	$.email_empty[Пожалуйста, укажите адрес электронной почты]
	$.email_wrong[Пожалуйста, укажите адрес электронной почты, похожий на адрес]
	$.user_not_found[user_not_found]
	$.multiple_user_found[multiple_user_found]
	$.unknown[Неизвестная ошибка авторизации]
]
^if($tErrors){
	^tErrors.menu{$hLabels.[$tErrors.name]}[<br/>]
}

###########################################################################
# print html for logout form
@htmlFormLogout[hParam]
^if($is_logon){
	$hParam[^hash::create[$hParam]]
# 	^untaint[html]{
# 		<form
# 			method="post"
# 			^if(def $hParam.target_url){
# 				action="$hParam.target_url"
# 			}
# 		>
# 			<input type="hidden" name="auth.logout" value="do" />
# 			<input type="submit" name="action" value="^if(def $hParam.action_name){$hParam.action_name}{Завершить работу}" />
# 		</form>
# 	}
	^untaint[html]{
		<a href="/?auth.logout=do">^if(def $hParam.action_name){$hParam.action_name}{Выйти}</a>
	}
}
#end @htmlFormLogout[]
