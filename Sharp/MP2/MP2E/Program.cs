using System;
using Microsoft.Office.Interop.Excel;

namespace MP2E
{
    internal class Program
    {
        static void Main(string[] args)
        {
            var XL1 = new Application();

            XL1.Visible = true;

            var t = Type.Missing;

            var Book1 = XL1.Workbooks.Add(t);

            var Lists = Book1.Worksheets;

            Worksheet List1 = Lists.Item[1];

            string[] Mas = {"Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"};

            int[] Mas1 = {100000, 120000, 150000, 130000, 170000, 190000, 210000, 230000, 250000, 270000, 290000, 310000};

            List1.Range["A1", t].Value2 = "Месяцы";

            List1.Range["B1", t].Value2 = "Продажи";

            List1.Range["C1", t].Value2 = "Налог";



            for (int i = 0; i < Mas.Length; i++)
            {
                List1.Cells[i + 2, 1] = Mas[i];
                List1.Cells[i + 2, 2] = Mas1[i];
                List1.Cells[i + 2, 3] = Mas1[i] * 0.18;
            }

            List1.Range["B14", t].Value2 = "Итого";
            List1.Range["C14", t].Value2 = "Итого";

            double sumSales = XL1.WorksheetFunction.Sum(List1.Range["B2:B13"]);
            double sumTax = XL1.WorksheetFunction.Sum(List1.Range["C2:C13"]);

            List1.Range["B15", t].Value2 = sumSales;
            List1.Range["C15", t].Value2 = sumTax;

            XL1.WorksheetFunction.Sum(List1.Range["B2:B13"]);
            Range range = XL1.get_Range("A1:C13");
            range.Borders.LineStyle = XlLineStyle.xlContinuous;
            range.Borders.Weight = XlBorderWeight.xlThin;

            Chart Graph = XL1.Charts.Add(t, t, t, t);
            Graph.ChartType = XlChartType.xlColumnClustered;
            Graph.SetSourceData(List1.Range["A1:C6"], t);
            Graph.HasLegend = false;
            Graph.HasTitle = true;
            Graph.ChartTitle.Caption = "Продажи за пять месяцев";
            XL1.ActiveChart.Export(@"D:/Graph.jpg", t, t);

        }
    }
}
