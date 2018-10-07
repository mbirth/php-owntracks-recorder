UPDATE locations SET dt=strftime('%s', dt) WHERE typeof(dt)='text';
VACUUM;
