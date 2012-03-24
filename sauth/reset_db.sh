#!/bin/sh

echo "Suppression des tables\n";
rm ./db/auth_dev.sqlite3;
rm ./db/auth_test.sqlite3;
echo "Creation des db vides\n";
ruby migration.rb;
echo "\nFin du script\n";