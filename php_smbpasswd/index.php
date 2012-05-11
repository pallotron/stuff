<html>
<head>
<title>SPMC Samba/NT domain password change</title>
</head>
<body>
	<img src="http://www.spmcsrl.it/img_index/spmcnew.gif">
	<h1>SPMC Samba/NT domain password change</h1>
	<hr/>
	<?
	include("captcha.php");

	$username = $_POST['username'];
	$oldpwd = $_POST['oldpwd'];
	$newpwd = $_POST['newpwd'];
	$newpwd2 = $_POST['newpwd2'];
	$action = $_GET['action'];

	$error = 0;

	if($username == "") 	{ $error = 1; $array_err[]['msg'] = "You must insert the username!"; }
	if($oldpwd == "") 		{ $error = 1; $array_err[]['msg'] = "You must insert the old password!"; }
	if($newpwd == "") 		{ $error = 1; $array_err[]['msg'] = "You must insert the new password!"; }
	if($newpwd2 == "") 		{ $error = 1; $array_err[]['msg'] = "You must retype the new password!"; }
	if($newpwd2 != $newpwd) { $error = 1; $array_err[]['msg'] = "The new passwords mismatch!"; }
	if(!captcha::check())   { $error = 1; $array_err[]['msg'] = "Please copy correctly the letters into the picture!"; }
	if($oldpwd == $newpwd)  { $error = 1; $array_err[]['msg'] = "Old and new passwords must be different!"; }

	if($error && $action == "do") {
		printf("<p>You made some errors!<br/><ul>");
		foreach($array_err as $err) {
			printf("<li>%s</li>",$err['msg']);
		}
		printf("</ul></p>");
		printf("<hr/>");
	}
	
	if(!$error && $username != "" && $oldpwd != "" && $newpwd != "" && $newpwd2 != "" && captcha::check() && $action == "do") {
		$fp = fsockopen("/usr/local/www/apache22/data/smbpasswd/tmp/changesmbpasswd.sock", 0, $errno, $errstr, 30);
		if (!$fp) {
			echo "$errstr ($errno)<br />\n";
		} else {
			fwrite($fp, "$username;$oldpwd;$newpwd\n");
			while (!feof($fp)) {
				$line.=fgets($fp, 128);
			}
			fclose($fp);
			if($line=="") echo "tutto ok";
			else echo $line;
		}
		printf("<hr/>");
	}
	?>
	
	<form name="smbpasswd" action="<?=$_SERVER['PHP_SELF']?>?action=do" method="POST">
	<table> 
	<tr>
	<td>
		username: 
	</td>
	<td>
		<input type="text" name="username" value="">
	</td>
	</tr>
	<tr>
	<td>
		old password: 
	</td>
	<td>
		<input type="password" name="oldpwd" value="">
	</td>
	</tr>
	<tr>
	<td>
		new password: 
	</td>
	<td>
		<input type="password" name="newpwd" value="">
	</td>
	</tr>
	<tr>
	<td>
		retype new  password: 
	</td>
	<td>
		<input type="password" name="newpwd2" value="">
	</td>
	</tr>
	<tr>
		<?php
			  echo( captcha::form() );
		?>
	</tr>
	<tr>
	<td colspan="2">
		<hr>
		<input type="submit" name="submit" value="change password">
		<input type="reset" name="reset" value="reset form">
		<input type="button" value="reload page" onClick="window.location.href=window.location.href">
	</td>
	</tr>
	</form>
	</p>
</body>
</html>
