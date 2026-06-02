CREATE OR REPLACE TRIGGER trg_pet_care_log_insert
BEFORE INSERT ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    -- Assign current system date/time and the current session user
    :NEW.LAST_UPDATE_DATETIME := SYSDATE;
    :NEW.CREATED_BY_USER      := USER;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'An error occurred while inserting the pet care log: ' || SQLERRM);
END;
/

CREATE OR REPLACE TRIGGER trg_pet_care_log_update
BEFORE UPDATE ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    -- Check if the current user matches the user who originally created the record
    IF USER != :OLD.CREATED_BY_USER THEN
        RAISE_APPLICATION_ERROR(-20002, 'Unauthorized Update: You can only update records that you created.');
    END IF;
    
    -- Automatically update the timestamp to the current time on a successful update
    :NEW.LAST_UPDATE_DATETIME := SYSDATE;

EXCEPTION
    WHEN OTHERS THEN
        -- Standard catch-all handler for unexpected database errors
        IF SQLCODE != -20002 THEN
            RAISE_APPLICATION_ERROR(-20003, 'An error occurred while updating the pet care log: ' || SQLERRM);
        ELSE
            RAISE; -- Re-raise the custom unauthorized error
        END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_pet_care_log_delete
BEFORE DELETE ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    -- Restrict deletion capabilities strictly to JOEMANAGER
    IF USER != 'JOEMANAGER' THEN
        RAISE_APPLICATION_ERROR(-20004, 'Unauthorized Delete: Only JOEMANAGER is permitted to delete log records.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        -- Standard catch-all handler for unexpected database errors
        IF SQLCODE != -20004 THEN
            RAISE_APPLICATION_ERROR(-20005, 'An error occurred while deleting the pet care log: ' || SQLERRM);
        ELSE
            RAISE; -- Re-raise the custom unauthorized error
        END IF;
END;
/