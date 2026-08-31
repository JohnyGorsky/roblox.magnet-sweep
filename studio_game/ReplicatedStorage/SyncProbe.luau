--!strict
-- TEMPORARY sync probe, written after a PC restart to prove Studio Sync is live.
-- PITFALLS #11: a file saved into a DROPPED connection looks exactly like a file that synced, so
-- the only honest test is to write something NEW and read the DataModel back.
return { marker = "SYNC_PROBE_AFTER_RESTART" }
