using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace EApplication.Data
{
    public partial class SqlOperator
    {
        public int Id { get; set; }
        public bool CloseModulo { get; set; }
        public bool CloseParenthesis { get; set; }
        [Required]
        [StringLength(50)]
        public string Ddl { get; set; }
        public bool Enabled { get; set; }
        [Required]
        [StringLength(1000)]
        public string Name { get; set; }
        public bool OpenModulo { get; set; }
        public bool OpenParenthesis { get; set; }
    }
}
