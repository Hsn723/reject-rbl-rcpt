conn = mt.connect("inet:3000@localhost")
assert(conn, "could not open connection")

local err = mt.rcptto(conn, "no-mx@example.com")
assert(err == nil, err)
assert(mt.getreply(conn) == SMFIR_CONTINUE)

local err = mt.rcptto(conn, "exist@festivaljapon.com")
assert(err == nil, err)
assert(mt.getreply(conn) == SMFIR_CONTINUE)

local err = mt.macro(conn, SMFIC_MAIL, "i", "test-id")
assert(err == nil, err)
assert(mt.getreply(conn) == SMFIR_CONTINUE)

local err = mt.eom(conn)
assert(err == nil, err)
assert(mt.getreply(conn) == SMFIR_CONTINUE)

local err = mt.disconnect(conn)
assert(err == nil, err)
