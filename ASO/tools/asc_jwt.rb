#!/usr/bin/env ruby
# Génère un JWT ES256 pour l'API App Store Connect.
# Usage: asc_jwt.rb <key_path> <key_id> <issuer_id>
# N'affiche jamais la clé privée, seulement le JWT (valable 20 min).

require 'openssl'
require 'json'
require 'base64'

key_path, key_id, issuer_id = ARGV
abort "usage: asc_jwt.rb <key_path> <key_id> <issuer_id>" unless key_path && key_id && issuer_id

def b64(data)
  Base64.urlsafe_encode64(data).delete('=')
end

now = Time.now.to_i
header  = { alg: 'ES256', kid: key_id, typ: 'JWT' }
payload = { iss: issuer_id, iat: now, exp: now + 1200, aud: 'appstoreconnect-v1' }

signing_input = "#{b64(JSON.generate(header))}.#{b64(JSON.generate(payload))}"

key = OpenSSL::PKey::EC.new(File.read(key_path))
der = key.dsa_sign_asn1(OpenSSL::Digest::SHA256.digest(signing_input))

# DER (SEQUENCE de 2 INTEGER) -> JOSE (r||s, 32 octets chacun)
r, s = OpenSSL::ASN1.decode(der).value.map { |v| v.value.to_s(2) }
raw = [r, s].map { |x| x.rjust(32, "\x00") }.join

print "#{signing_input}.#{b64(raw)}"
