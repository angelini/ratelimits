local ngx = ngx
local http = require("resty.http")
local cjson = require("cjson.safe")

local _M = {}

function string:endswith(suffix)
  return self:sub(-#suffix) == suffix
end

function remove_port(host)
  local port_idx = string.find(host, ":")
  if port_idx ~= nil then
    host = string.sub(host, 0, port_idx-1)
  end
  return host
end

function is_ratelimited_host(host)
  return host:endswith("local")
end

function rate_for_host(host)
  -- TODO: change the rate based on the hostname
  return 5
end

function _M.rewrite()
  local httpc = http.new()

  local host = remove_port(ngx.req.get_headers()["Host"])
  if not is_ratelimited_host(host) then
    return
  end

  local key = "host:" .. host

  local body = {
    requests={
      {
        name="requests_per_sec",
        unique_key=key,
        hits=1,
        limit=rate_for_host(host),
        duration=10000,
        algorithm=1
      }
    }
  }

  local body_json = cjson.encode(body)

  local res, err = httpc:request_uri("http://gubernator.gubernator.svc.cluster.local/v1/GetRateLimits", {
    method = "POST",
    body = body_json,
    headers = {
        ["Content-Type"] = "application/json",
    },
  })
  if not res then
      ngx.log(ngx.ERR, "request failed: ", err)
      return
  end

  local res_body = cjson.decode(res.body)
  local status = res_body.responses[1].status
  if status == "OVER_LIMIT" then
    ngx.stauts = 429
    ngx.log(ngx.ERR, "Host over request limit: ", host)
    ngx.exit(ngx.HTTP_FORBIDDEN)
  end
end

return _M
