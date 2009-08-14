migration 1, :drop_not_null_constraint_on_user_id_in_topic_flags_and_topic_element_flags  do
  up do
    execute "alter table topic_flags modify user_id int(11) NULL"
    execute "alter table topic_element_flags modify user_id int(11) NULL"
  end

  down do
    execute "alter table topic_flags modify user_id int(11) NOT NULL"
    execute "alter table topic_element_flags modify user_id int(11) NOT NULL"
  end
end
