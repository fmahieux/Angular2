using EApplication.Data.Identity;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace EApplication.Data
{
  public partial class EAppdbContext : IdentityDbContext<ApplicationUser>
  {
    public EAppdbContext()
    {
    }

    public EAppdbContext(DbContextOptions<EAppdbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<SqlDatatype> SqlDatatype { get; set; }
    public virtual DbSet<SqlObject> SqlObject { get; set; }
    public virtual DbSet<SqlOperator> SqlOperator { get; set; }
    public virtual DbSet<SqlSource> SqlSource { get; set; }
    public virtual DbSet<SqlSourceType> SqlSourceType { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
      if (!optionsBuilder.IsConfigured)
      {
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. See http://go.microsoft.com/fwlink/?LinkId=723263 for guidance on storing connection strings.
        optionsBuilder.UseSqlServer("Data Source=(localdb)\\MSSQLLocalDB;Initial Catalog=TestDb;Integrated Security=True");
      }
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
      modelBuilder.Entity<SqlDatatype>(entity =>
      {
        entity.Property(e => e.Id).ValueGeneratedNever();

        entity.Property(e => e.Name).IsUnicode(false);
      });

      modelBuilder.Entity<SqlObject>(entity =>
      {
        entity.Property(e => e.Id).ValueGeneratedNever();

        entity.Property(e => e.Description).IsUnicode(false);

        entity.Property(e => e.Name).IsUnicode(false);
      });

      modelBuilder.Entity<SqlOperator>(entity =>
      {
        entity.Property(e => e.Id).ValueGeneratedNever();

        entity.Property(e => e.Ddl).IsUnicode(false);

        entity.Property(e => e.Name).IsUnicode(false);
      });

      modelBuilder.Entity<SqlSource>(entity =>
      {
        entity.Property(e => e.Id).ValueGeneratedNever();

        entity.Property(e => e.Description).IsUnicode(false);

        entity.Property(e => e.ForJson).IsUnicode(false);

        entity.Property(e => e.Name).IsUnicode(false);

        entity.Property(e => e.Statement).IsUnicode(false);
      });

      modelBuilder.Entity<SqlSourceType>(entity =>
      {
        entity.Property(e => e.Id).ValueGeneratedNever();

        entity.Property(e => e.Name).IsUnicode(false);
      });

      base.OnModelCreating(modelBuilder);
      //OnModelCreatingPartial(modelBuilder);
    }

    //partial void OnModelCreatingPartial(ModelBuilder modelBuilder);

  }
}
