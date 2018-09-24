using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Configuration;

namespace EApplication.Filters
{
  internal class AntiforgeryCookieResultFilter : ResultFilterAttribute
  {
    public AntiforgeryCookieResultFilter(IAntiforgery antiforgery, IConfiguration configuration)
    {
      this._antiforgery = antiforgery;
      this._configuration = configuration;
    }

    private readonly IAntiforgery _antiforgery;
    private readonly IConfiguration _configuration;

    public override void OnResultExecuting(ResultExecutingContext context)
    {

      var tokens = this._antiforgery.GetAndStoreTokens(context.HttpContext);
      context.HttpContext.Response.Cookies.Append(_configuration.GetValue<string>("Antiforgery:XSRF-Token"), tokens.RequestToken, new CookieOptions
      {
        HttpOnly = false
      });
    }
  }
}

