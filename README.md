# ITchallenge

Precondiciones:

Ruby gems:
  rubygems
  net/ldap (sudo gem install net-ldap)
  csv
  mail (sudo gem install mail)

Parametros a configurar en ImportarUsuarios.rb:



Instrucciones:
  Ejecutar: ruby ImportarUsuarios.rb
  Completar con el path del archivo de usuarios a importar, cuando se le solicite.
  El programa enviara un mail a cada usuario del archivo informando su nuevo nombre de usuario o
  si ocurrio algun error.

Probado con:
  SO: Lubuntu 16.04
  Ruby: ruby 2.3.0p0 (2015-12-25) [x86_64-linux-gnu]
  OpenLDAP: @(#) $OpenLDAP: slapd  (Ubuntu) (May 11 2016 16:12:05) $
	           buildd@lgw01-10:/build/openldap-mF7Kfq/openldap-2.4.42+dfsg/debian/build/servers/slapd
