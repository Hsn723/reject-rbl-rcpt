mt.echo("test enforce with bad IP")
mt.startfilter("target/debug/reject-rbl-rcpt", "-m", "enforce", "-l", "inet:31000@localhost")
mt.sleep(2)

conn = mt.connect("inet:31000@localhost")
assert(conn, "could not open connection")

local err = mt.rcptto(conn, "exist@festivaljapon.com")
assert(err == nil, err)
assert(mt.getreply(conn) == SMFIR_CONTINUE)

local err = mt.rcptto(conn, "bad@mail-test.hoshino.dev")
assert(err == nil, err)
assert(mt.getreply(conn) == SMFIR_CONTINUE)

local err = mt.macro(conn, SMFIC_MAIL, "i", "test-id")
assert(err == nil, err)
assert(mt.getreply(conn) == SMFIR_CONTINUE)

local err = mt.eom(conn)
assert(err == nil, err)
assert(mt.getreply(conn) ~= SMFIR_CONTINUE)

local err = mt.disconnect(conn)
assert(err == nil, err)
