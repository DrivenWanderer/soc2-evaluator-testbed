using System.Web.Mvc;

namespace LegacyPortal.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            ViewBag.Title = "Ledgerly Legacy Customer Portal";
            return Content("Ledgerly Legacy Portal - Running");
        }
    }
}
