﻿## Описание

Веб приложение для поиска статей в документации InterSystems. 
Задача: обеспечить оперативный и эффективный поиск статей в документации InterSystems.
## Технологическое описание

Приложение представляет из себя клиент-серверный комплекс, размещяемый на Windows системе, 
и доступный через интерфейс страниц веб сайта по заданному адресу с помощью веб браузера.  
На сервере работает приложение: 

1. На языке Cache Object Script  -  отвечающее за работу с базой данных, 
бизнес логику и обмен основными данными с клиентским приложением;

Также используется клиентское приложение, написанное на языке Javascript и фреймворке Angular.
Приложение работает в браузере и отвечает за работу интерфейса веб страницы и обмен данными с сервером. 


## Технологии

Server system           -   Windows 7/8/10  
App client side         -   Angular.js (Javascript ES5)  
App server side         -   Intersystems Ensemble 2017.1
App database            -   Intersystems Ensemble 2017.1



### Подготовка окружения

1. Убедиться, что стоит Intersystems Cache, Ensemble или Healthshare версии 2017.1 или позднее и есть лицензия (необходимо для работы iKnow).
2. Загрузить Installer.xml из релиза
3. Импортировать Installer.xml в область %SYS через Студию, скомпилировать. В терминале в области %SYS ввести следующую команду:
	do ##class(Docsearch.Installer).setup(.pVars)
 Процесс занимает около 30 минут.
 Поиск доступен по адресу http://localhost:[порт]/csp/docsearch/index.csp


