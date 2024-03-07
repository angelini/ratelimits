local ngx = ngx
local _M = {}
function _M.rewrite()
  ngx.status = 403
  ngx.log(ngx.ERR, "Forbidden from limiter")
  ngx.exit(ngx.HTTP_FORBIDDEN)
end
return _M
