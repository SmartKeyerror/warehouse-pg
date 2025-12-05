-- Test the scenario which the huge gxid

-- start_matchsubs
-- m/cdbdistributedxid.c:\d+/
-- s/cdbdistributedxid.c:\d+/cdbdistributedxid.c:LINE/
-- m/cdbdistributedxacts.c:\d+/
-- s/cdbdistributedxacts.c:\d+/cdbdistributedxacts.c:LINE/
-- end_matchsubs

-- let the gxid exceed UINTMAX
select gp_set_next_gxid(4294967296); -- UINTMAX is 4294967295
select gp_get_next_gxid();

-- these 3 functions/view only work when using gp_toolkit version
begin;
select gp_distributed_xid();
end;
begin;
select gp_toolkit.gp_distributed_xid();
end;

begin;
select * from gp_distributed_xacts;
end;
begin;
select distributed_xid,state,xmin_distributed_snapshot from gp_toolkit.gp_distributed_xacts order by distributed_xid desc limit 1;
end;

0U:select segment_id from gp_toolkit.gp_distributed_log group by segment_id;
