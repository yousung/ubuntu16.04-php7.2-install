# ubuntu16.04 / php7.2 Install

### History
* 2018-05 : First Write

### Dev
* nug22kr@gmail.com

### Setup
```wget https://raw.githubusercontent.com/yousung/ubuntu16.04-php7.2-install/master/script/install-php7.2.sh``` <br/>
```adduser user-id``` <br/>
```usermod -G www-data user-id``` <br/>
```id user-id``` <br/>
```// uid=xxx(user-id) gid=xxx(user-id) groups=xxx(user-id),xx(www-data)``` <br/>
```sudo -s``` <br/>
```bash install-php7.2.sh user-id``` <br/>
<br/>
<br/>
```wget https://raw.githubusercontent.com/yousung/ubuntu16.04-php7.2-install/master/script/server.sh``` <br/>
```bash server.sh example.com /path/to/document-root``` <br/>
