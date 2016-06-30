#!/usr/bin/ruby

# NOTAS:
# Se omiten los acentos en la totalidad del codigo y comentarios.
# Espero que les guste!


# Variables para configurar:

# Usuario de ldap con privilegios para crear entradas
ldapuser = "cn=admin,dc=dnsdtest,dc=com"
# Password del usuario ldap
ldappasswd = "izanami"
# IP del servidor ldap
ldaphost = "127.0.0.1"
# Puerto del servidor ldap
ldapport = "389"
# Base del servidor
ldapbase = "dc=dnsdtest,dc=com"
# Dependiendo del tipo de encriptacion que utiliza el servidor
# se debería cambiar el siguiente parametro
#  :encryption => :simple_tls,
tls_encryption = false
# Usuario de gmail, para este ejemplo, con la opcion de "aplicaciones menos seguras" activada.
# Este sera el remitente de los mails informativos
# Este que viene seteado funciona:
gmailuser = "itchallengetest@gmail.com"
# Contraseña del usuario de gmail.
gmailpasswd = "quinn1234"
# Esta variable define si se va a enviar un mail en caso de que el usuario no haya sido creado.
send_failure_mail = true
# Esta variable define si los usuarios van a ser creados con password,
# dependiendo del tipo de conexion a LDAP (tls, ssl), crear usuarios con password
# podria fallar.
users_with_passwd = false


#################################################

require 'rubygems'
require 'net/ldap'
require 'csv'
require 'mail'

#################################################
# Configuro opciones de mail
#################################################

options = {
  :address => "smtp.gmail.com",
  :port => 587,
  :domain => "localhost",
  :user_name => gmailuser,
  :password => gmailpasswd,
  :authentication => 'plain',
  :enable_starttls_auto => true
}

Mail.defaults do
  delivery_method :smtp, options
end



#################################################
# Conexion con ldap
#################################################

# Este metodo ayuda a interpretar los return de ldap (bind, search, add, modify, rename, delete).
# Quiza me sirva mas adelante.

def get_ldap_response(ldap)
  msg = "Response Code: #{ ldap.get_operation_result.code }, Message: #{ ldap.get_operation_result.message }"

  raise msg unless ldap.get_operation_result.code == 0
end

# Dejo establecidos los parametros de  conexion con ldap
# Con este metodo no hay trafico de red, todavia.

ldap = Net::LDAP.new :host => ldaphost,
:port => ldapport,
#:encryption => :simple_tls,
:base => ldapbase,
:auth => {
  :method => :simple,
  :username => ldapuser,
  :password => ldappasswd,
}

# Pruebo la conexion
puts ' '
puts '********************'
puts 'Pruebo la conexion:'
puts '********************'
puts ' '

if ldap.bind
	puts "Connection successful!  Code:  #{ldap.get_operation_result.code}, message: #{ldap.get_operation_result.message}"
else
	puts "Connection failed!  Code:  #{ldap.get_operation_result.code}, message: #{ldap.get_operation_result.message}"
end

#################################################
# Un intento basico de search en ldap
#################################################
puts ' '
puts '********************'
puts 'Listado de usuarios:'
puts '********************'
puts ' '

# Creo el filtro
search_filter = Net::LDAP::Filter.eq("objectClass","person")

# Ejecuto la busqueda
ldap.search(:base=>"dc=dnsdtest,dc=com",:filter=>search_filter,:attributes=>'dn') do |entry|
  puts "DN: #{entry.dn}"
end

# Respuestas?
get_ldap_response(ldap)

#################################################
# Importar CSV
#################################################
puts ' '
puts '********************'
puts 'Creando usuarios:'
puts '********************'
puts ' '

puts 'Ingrese la direccion del archivo CSV a importar:'
puts 'Ejemplo: ../test/usuarios_example.csv'
puts ' '
csvfile = "../test/usuarios_example.csv"#gets.chomp
puts ' '

while (!File.file?(csvfile)) do
  puts 'El path ingresado es incorrecto, vuelva a intentarlo.'
  puts ' '
  csvfile = gets.chomp
  puts ' '
end

csvarray = CSV.read(csvfile, {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all})

hashed_data = csvarray.map { |d| d.to_hash }

hashed_data.each { |data|

  # Todo esto tendria que estar en una funcion aparte, mejorar mas adelante.

  first_name = data[:nombre]
  last_name = data[:apellido]
  username = first_name[0].downcase + last_name.downcase
  fullname = first_name + " " + last_name
  usermail = data[:email]
  plain_passwd = " "

  dn = "uid="+username+",ou=users,dc=dnsdtest,dc=com"

  # Dependiendo de  si va a tener password o no, armo los atributos
  if users_with_passwd then

    # Creo una passwd
    plain_passwd = ""; 8.times{plain_passwd << ((rand(2)==1?65:97) + rand(25)).chr}
    # Codifico la passwd con md5
    coded_password = Net::LDAP::Password.generate(:md5, plain_passwd)

    # Esto no lo probe, dado que mi conexion de OpenSSL no me permitia
    # autentificarme en el LDAP

    attrs = {
      :objectclass => ["User"],
      :cn => username,
      :sn => last_name.capitalize,
      :givenname => first_name.capitalize,
      :unicodePwd => coded_password
    }

  else
    attrs = {
      :objectclass => ["User"],
      :cn => username,
      :sn => last_name.capitalize,
      :givenname => first_name.capitalize,
      }
  end

  # Creo el usuario
  ldap.add(:dn => dn, :attributes => attrs)

  # Envio el mail correspondiente
  if ldap.get_operation_result.code != 0
    puts "Failed to add user #{fullname}"

    if(send_failure_mail) then
    Mail.deliver do
      to data[:email]
      from 'itchallengetest@gmail.com'
      subject 'No se ha podido crear su usuario.'
      body 'No se ha podido crear su nuevo usuario para acceder a ' + ldaphost + ', ' + username + ' (Contraseña: ' + plain_passwd + ')'
    end
  end

  else
    puts "Added user #{fullname}"
      Mail.deliver do
        to data[:email]
        from 'itchallengetest@gmail.com'
        subject 'Su nuevo usuario a sido creado.'
        body 'Su nuevo usuario para acceder a ' + ldaphost + 'es: ' + username+ ' y su contraseña es: '+ plain_passwd
      end
  end
}

#################################################
# Fin
#################################################
puts ' '
puts '********************'
puts 'FIN'
puts '********************'
puts ' '
