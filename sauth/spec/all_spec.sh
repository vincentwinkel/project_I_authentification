#!/bin/sh

case $1 in
  doc)
    rspec user_spec.rb --format documentation;
    rspec application_spec.rb --format documentation;
    rspec app_user_spec.rb --format documentation;
    rspec sauth_spec.rb --format documentation;
  ;;
  *)
    rspec user_spec.rb;
    rspec application_spec.rb;
    rspec app_user_spec.rb;
    rspec sauth_spec.rb;
  ;;
esac
