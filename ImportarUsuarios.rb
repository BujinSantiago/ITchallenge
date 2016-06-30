#!/usr/bin/ruby

# NOTAS:
# Se omiten los acentos en la totalidad del codigo y comentarios.
# Encriptado de credenciales :simple_tls esta comentado por que me traia probemas con el ssl de la maquina virtual. (Perdi mucho tiempo tratando de solucionarlo)
# Espero que les guste!


# Variables para configurar:

# Usuario de ldap con privilegios para crear entradas
ldapuser = "cn=admin,dc=dnsdtest,dc=com"
# Password del usuario ldap
ldappasswd = "izanami"


#################################################

require 'rubygems'
require 'net/ldap'
require 'csv'

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

ldap = Net::LDAP.new :host => "127.0.0.1", # Hacer global
:port => "389",
#:encryption => :simple_tls,
:base => "dc=dnsdtest,dc=com",
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
puts 'Importando CSV:'
puts '********************'
puts ' '

csvarray = CSV.read("usuarios.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all})

hashed_data = csvarray.map { |d| d.to_hash }

hashed_data.each { |data|
  puts data[:nombre]
  adduser(:nombre, :apellido, :nombre)
}

#################################################
# Creo nuevo usuario
#################################################
puts ' '
puts '********************'
puts 'Creando usuarios:'
puts '********************'
puts ' '

dn = "uid=test,ou=users,dc=dnsdtest,dc=com"

first_name = "TEST"
last_name = "JEST"
username = "testjest"
fullname = first_name + " " + last_name

attrs = {
  #:objectclass => ["top", "person"],
  :cn => fullname,
  :sn => last_name.capitalize,
  #:givenname => first_name.capitalize,
  #:displayname => fullname,
  #:name => fullname,
  #:samaccountname => username,
  #:unicodePwd => '"password"'.encode("utf-16")
}
ldap.add(dn: dn, attributes: attrs)

if ldap.get_operation_result.code != 0
  puts "Failed to add user #{fullname}"
else
  puts "Added user #{fullname}"
end

#################################################
# Fin
#################################################
puts ' '
puts '********************'
puts 'FIN'
puts '********************'
puts ' '
