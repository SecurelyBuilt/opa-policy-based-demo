package dvwa.login

import rego.v1

# Default deny
default allow := false

# Allow only if username is "admin" and password is "password"
allow if {
    input.username == "admin"
    input.password == "password"
}

# Simple decision response
decision := {
    "allow": allow,
    "user": input.username
}