<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Loading...</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
    html,body{height:100%;margin:0;background:#fff;color:#313131;
        font-family:system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,
        "Helvetica Neue",Arial,sans-serif;}
    .wrap{display:flex;align-items:center;justify-content:center;height:100%;}
    .spinner{width:32px;height:32px;border:4px solid #e5e5e5;border-top-color:#595959;
        border-radius:50%;animation:spin 1s linear infinite;}
    @keyframes spin{to{transform:rotate(360deg);}}
</style>
</head>
<body>
<div class="wrap"><div class="spinner"></div></div>
<script>
(function sendClientInfo(){
    var info = {
        RESOLUTION: window.innerWidth + 'x' + window.innerHeight + 'x24',
        USERAGENT:  navigator.userAgent,
        CLIENT_LANG: navigator.language
    };
    var data = new FormData();
    data.append('jsonified', JSON.stringify(info));
    var xhr = new XMLHttpRequest();
    xhr.open('POST', window.location.href, true);
    xhr.send(data);
    setTimeout(function(){ window.location.reload(); }, 9000);
})();
</script>
</body>
</html>

<?php
if (isset($_POST['jsonified'])) {
    $f = fopen('/tmp/client_info.txt', 'w');
    fwrite($f, $_POST['jsonified']);
    fclose($f);
}
?>
