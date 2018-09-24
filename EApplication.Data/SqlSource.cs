using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace EApplication.Data
{
    public partial class SqlSource
    {
        public int Id { get; set; }
        [Required]
        [StringLength(1000)]
        public string Description { get; set; }
        public bool Enabled { get; set; }
        [Required]
        [StringLength(50)]
        public string ForJson { get; set; }
        [Required]
        [StringLength(1000)]
        public string Name { get; set; }
        public int SqlSourceTypeId { get; set; }
        [Required]
        [StringLength(1000)]
        public string Statement { get; set; }
    }
}
