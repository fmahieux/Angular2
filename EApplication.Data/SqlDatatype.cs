using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace EApplication.Data
{
    public partial class SqlDatatype
    {
        public int Id { get; set; }
        [Required]
        [StringLength(1000)]
        public string Name { get; set; }
    }
}
