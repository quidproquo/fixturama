module Fixturama::Config
  module_function

  #
  # @param [#to_i] value
  # @return [Boolean]
  #
  def start_ids_from(value)
    require "active_record"

    db_name = ActiveRecord::Base.connection_config[:database]
    sql = format(SEQUENCE_BOOST_SCRIPT, db_name: db_name, min_id: value.to_i)
    ActiveRecord::Base.connection.execute(sql)

    true
  rescue LoadError
    false
  end

  # @private
  SEQUENCE_BOOST_SCRIPT = <<~SQL.freeze
    DO $$
    DECLARE
    seq_name TEXT;

    BEGIN
      FOR seq_name IN (select table_name from information_schema.tables where
        table_catalog='%<db_name>s' and table_schema='public') LOOP
      BEGIN
        EXECUTE ' \
          SELECT setval('''||seq_name||'_id_seq''::regclass, %<min_id>s); ';
      EXCEPTION
        WHEN undefined_table THEN
          NULL;
      END;
      END LOOP;
    END$$;
  SQL
end
