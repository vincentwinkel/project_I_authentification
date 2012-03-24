#!/bin/sh

sep="####################################################";
doc="";
function line() {
	echo "\n${sep}\n${*}\n${sep}\n";
}

if [ "$1" == "doc" ]; then
	doc="--format documentation";
fi

line "Tests de user.rb";
rspec user_spec.rb $doc;
line "Tests de application.rb";
rspec application_spec.rb $doc;
line "Tests de app_user.rb";
rspec app_user_spec.rb $doc;
line "Tests de sauth.rb";
rspec sauth_spec.rb $doc;
echo "\nFin des tests\n\n";
