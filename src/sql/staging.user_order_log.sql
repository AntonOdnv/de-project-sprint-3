DO $$
BEGIN
	IF EXISTS (SELECT * 
			   FROM information_schema.TABLES
			   WHERE table_name = 'user_order_log' AND table_schema = 'staging')
	THEN EXECUTE 'DELETE FROM staging.user_order_log WHERE date_time::date = ''{{ ds }}''';
	END IF;
END $$;