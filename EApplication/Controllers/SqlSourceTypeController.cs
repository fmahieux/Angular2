using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using EApplication.Data;

namespace EApplication.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SqlSourceTypeController : ControllerBase
    {
        private readonly EAppdbContext _context;

        public SqlSourceTypeController(EAppdbContext context)
        {
            _context = context;
        }

        // GET: api/SqlSourceType
        [HttpGet]
        public IEnumerable<SqlSourceType> GetSqlSourceType()
        {
            return _context.SqlSourceType;
        }

        // GET: api/SqlSourceType/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetSqlSourceType([FromRoute] int id)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var sqlSourceType = await _context.SqlSourceType.FindAsync(id);

            if (sqlSourceType == null)
            {
                return NotFound();
            }

            return Ok(sqlSourceType);
        }

        // PUT: api/SqlSourceType/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutSqlSourceType([FromRoute] int id, [FromBody] SqlSourceType sqlSourceType)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            if (id != sqlSourceType.Id)
            {
                return BadRequest();
            }

            _context.Entry(sqlSourceType).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!SqlSourceTypeExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return NoContent();
        }

        // POST: api/SqlSourceType
        [HttpPost]
        public async Task<IActionResult> PostSqlSourceType([FromBody] SqlSourceType sqlSourceType)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            _context.SqlSourceType.Add(sqlSourceType);
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                if (SqlSourceTypeExists(sqlSourceType.Id))
                {
                    return new StatusCodeResult(StatusCodes.Status409Conflict);
                }
                else
                {
                    throw;
                }
            }

            return CreatedAtAction("GetSqlSourceType", new { id = sqlSourceType.Id }, sqlSourceType);
        }

        // DELETE: api/SqlSourceType/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteSqlSourceType([FromRoute] int id)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var sqlSourceType = await _context.SqlSourceType.FindAsync(id);
            if (sqlSourceType == null)
            {
                return NotFound();
            }

            _context.SqlSourceType.Remove(sqlSourceType);
            await _context.SaveChangesAsync();

            return Ok(sqlSourceType);
        }

        private bool SqlSourceTypeExists(int id)
        {
            return _context.SqlSourceType.Any(e => e.Id == id);
        }
    }
}