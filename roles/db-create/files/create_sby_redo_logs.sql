SET SERVEROUTPUT ON
DECLARE
    v_group NUMBER;
    v_ddl   VARCHAR2(32767);
BEGIN
    FOR r_del IN (SELECT group# FROM   v$standby_log) LOOP
        DBMS_OUTPUT.PUT_LINE ('Dropping standby redolog group '||r_del.group#);
        v_ddl := 'ALTER DATABASE DROP STANDBY LOGFILE GROUP ' ||r_del.group#;
        DBMS_OUTPUT.PUT_LINE (v_ddl);
        EXECUTE IMMEDIATE v_ddl;
    END LOOP;

    SELECT Max (group#) + 1 INTO   v_group FROM   v$log;

    FOR r_rec IN (SELECT thread#,bytes,Count (*) Cnt
                 FROM   v$log
                 GROUP  BY thread#,
                           bytes
                 ORDER  BY 1) LOOP
        FOR r_redo IN 1..r_rec.cnt + 1 LOOP
            DBMS_OUTPUT.PUT_LINE ('Creating standby redolog for thread '||r_rec.thread#||' group ');
            v_ddl := 'ALTER DATABASE ADD STANDBY LOGFILE THREAD '
                     ||r_rec.thread#
                     ||' GROUP '
                     ||v_group
                     ||' SIZE '
                     ||r_rec.bytes;
            DBMS_OUTPUT.PUT_LINE (v_ddl);
            EXECUTE IMMEDIATE v_ddl;
            v_group := v_group + 1;
        END LOOP;
    END LOOP;
END;
/ 