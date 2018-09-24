using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace EApplication.Data
{
    public partial class SqlObject
    {
        public int Id { get; set; }
        public int? DeleteId { get; set; }
        [Required]
        [StringLength(255)]
        public string Description { get; set; }
        public bool Enabled { get; set; }
        public int? InsertId { get; set; }
        [Required]
        [StringLength(100)]
        public string Name { get; set; }
        public int SelectId { get; set; }
        public int? UpdateId { get; set; }
    }
}
