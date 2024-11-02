using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.Owin;
using Microsoft.Owin.Security;
using Microsoft.Owin.Security.Cookies;
using Microsoft.Owin.Security.OpenIdConnect;
using Owin;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Threading.Tasks;
using System.Web;

namespace WebApplication1
{
    public partial class Startup
    {
        public void ConfigureAuth(IAppBuilder app)
        {
            app.SetDefaultSignInAsAuthenticationType(CookieAuthenticationDefaults.AuthenticationType);
            app.UseCookieAuthentication(new CookieAuthenticationOptions());
            app.UseOpenIdConnectAuthentication(
                new OpenIdConnectAuthenticationOptions
                {
                    ClientId = ConfigurationManager.AppSettings["ClientId"],
                    Authority = ConfigurationManager.AppSettings["Authority"],
                    Notifications = new OpenIdConnectAuthenticationNotifications
                    {
                        RedirectToIdentityProvider = (o) =>
                        {
                            o.ProtocolMessage.RedirectUri = DetermineRedirectUri(o.Request);
                            return Task.CompletedTask;
                        },
                        AuthorizationCodeReceived = (o) =>
                        {
                            o.TokenEndpointRequest.RedirectUri = DetermineRedirectUri(o.Request);
                            return Task.CompletedTask;
                        }
                    }
                }
            );
        }

        private string DetermineRedirectUri(IOwinRequest request)
        {
            return request.Scheme + Uri.SchemeDelimiter + request.Host + request.PathBase;
        }
    }
}