using System;
using System.Collections.Generic;
using System.Text;
using EApplication.Data.Identity;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;

namespace EApplication.Data.Extensions
{
  public static class DatabaseExtension
  {
    public static void AddDatabaseExtension(this IServiceCollection services)
    {
      services.AddIdentity<ApplicationUser, IdentityRole>()
        .AddEntityFrameworkStores<EAppdbContext>()
        .AddDefaultTokenProviders();

      services.AddScoped<EAppdbContext>();
      services.AddTransient<UserManager<ApplicationUser>>();
    }
  }
}
