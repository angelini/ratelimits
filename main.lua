local ngx = ngx
local http = require("resty.http")

local _M = {}

function _M.rewrite()
  local httpc = http.new()
  local res, err = httpc:request_uri("http://gubernator.gubernator.svc.cluster.local/v1/GetRateLimits", {
    method = "POST",
    body = '{"requests":[{"name":"requests_per_sec","unique_key":"example:1","hits":1,"limit":5,"duration":10000,"algorithm":1}]}',
    headers = {
        ["Content-Type"] = "application/json",
    },
  })
  if not res then
      ngx.log(ngx.ERR, "request failed: ", err)
      return
  end

  ngx.log(ngx.ERR, "request succeeded: ", res.status)
  ngx.log(ngx.ERR, "body: ", res.body)
end

return _M
