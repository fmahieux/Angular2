using System;
using EApplication.Data;
using EApplication.Data.Extensions;
using EApplication.Filters;
using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.HttpsPolicy;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SpaServices.AngularCli;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Swashbuckle.AspNetCore.Swagger;

namespace EApplication
{
  public class Startup
  {
    public Startup(IConfiguration configuration)
    {
      Configuration = configuration;
    }

    public IConfiguration Configuration { get; }

    // This method gets called by the runtime. Use this method to add services to the container.
    public void ConfigureServices(IServiceCollection services)
    {
      services.AddMvc(
          options =>
          {
            options.Filters.AddService(typeof(AntiforgeryCookieResultFilter));
          }
        ).SetCompatibilityVersion(CompatibilityVersion.Version_2_1);


      //services.AddMvc().SetCompatibilityVersion(CompatibilityVersion.Version_2_1);
      AddIesegConfig(services);

      // In production, the Angular files will be served from this directory
      services.AddSpaStaticFiles(configuration =>
      {
        configuration.RootPath = "ClientApp/dist";
      });
    }

    // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
    public void Configure(IApplicationBuilder app, IHostingEnvironment env, IAntiforgery antiforgery)
    {
      if (env.IsDevelopment())
      {
        app.UseDeveloperExceptionPage();
      }
      else
      {
        app.UseExceptionHandler("/Error");
        app.UseHsts();
      }

      app.UseHttpsRedirection();
      app.UseStaticFiles();
      app.UseSpaStaticFiles();

      AddIesegApp(app, antiforgery);

      app.UseMvc(routes =>
            {
              routes.MapRoute(
                  name: "default",
                  template: "{controller}/{action=Index}/{id?}");
            });

      app.UseSpa(spa =>
      {
              // To learn more about options for serving an Angular SPA from ASP.NET Core,
              // see https://go.microsoft.com/fwlink/?linkid=864501

              spa.Options.SourcePath = "ClientApp";

        if (env.IsDevelopment())
        {
          spa.Options.StartupTimeout = new TimeSpan(0, 0, 120);
          spa.UseAngularCliServer(npmScript: "start");
        }
      });
    }

    private void AddIesegConfig(IServiceCollection services)
    {
      // database connection
      services.AddEntityFrameworkSqlServer();
      services.AddDbContext<EAppdbContext>(options =>
      {
        options.UseSqlServer(Configuration.GetConnectionString("DefaultConnection"));
      });

      services.AddDatabaseExtension();

      // Security
      services.AddAuthorization();
      services.AddTransient<AntiforgeryCookieResultFilter>();

      // Compression
      services.AddResponseCompression();

      // Cors
      services.AddCors(options =>
      {
        options.AddPolicy("AllowSpecificOrigin",
          builder =>
          {
            builder.WithOrigins(Configuration.GetConnectionString("CorsSetting"))
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
          });
      });

      // AntiForgery
      services.AddAntiforgery(options =>
      {
        options.Cookie.Domain = Configuration.GetConnectionString("Domain");
        options.Cookie.Name = Configuration.GetValue<string>("Antiforgery:Xsrf-Cookie");
        options.Cookie.Path = "Path";
        options.FormFieldName = "AntiforgeryFieldname";
        options.HeaderName = Configuration.GetValue<string>("Antiforgery:Xsrf-Header");
        options.Cookie.SecurePolicy = CookieSecurePolicy.Always ;
        options.SuppressXFrameOptionsHeader = false;
      });

      //Swagger
      services.AddSwaggerGen(c =>
      {
        c.SwaggerDoc("v1", new Info { Title = "My API", Version = "v1" });
      });
    }


    private void AddIesegApp(IApplicationBuilder app, IAntiforgery antiforgery)
    {
      app.UseResponseCompression();
      app.UseAuthentication();
      app.UseCors("AllowSpecificOrigin");

      app.Use(next => context =>
      {
        string path = context.Request.Path.Value;

        if (
          string.Equals(path, "/", StringComparison.OrdinalIgnoreCase) ||
          string.Equals(path, "/index.html", StringComparison.OrdinalIgnoreCase))
        {
          // The request token can be sent as a JavaScript-readable cookie, 
          // and Angular uses it by default.
          var tokens = antiforgery.GetAndStoreTokens(context);
          context.Response.Cookies.Append(Configuration.GetValue<string>("Antiforgery:Xsrf-Token"), tokens.RequestToken,
            new CookieOptions() { HttpOnly = false });
        }

        return next(context);
      });

      app.UseSwagger();
      app.UseSwaggerUI(c =>
      {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "EApplication API V1");
      });

    }
  }
}
