using MP11.Models; // Проверьте namespace
using System;
using System.Linq;
using System.Windows.Controls;
using System.Windows.Forms.DataVisualization.Charting;

namespace MP11
{
    public partial class ChartPage : Page
    {
        private DatabaseContext _context;

        public ChartPage()
        {
            InitializeComponent();
            _context = DatabaseContext.GetContext();
            LoadData();
        }

        private void LoadData()
        {
            // Загружаем студентов в ComboBox
            ComboUsers.ItemsSource = _context.Students.ToList();
            ComboUsers.DisplayMemberPath = "LastName";

            // Типы диаграмм
            ComboChartTypes.ItemsSource = Enum.GetValues(typeof(SeriesChartType));
            ComboChartTypes.SelectedItem = SeriesChartType.Column;
        }

        private void UpdateChart(object sender, SelectionChangedEventArgs e)
        {
            if (ComboUsers.SelectedItem is Student currentUser &&
                ComboChartTypes.SelectedItem is SeriesChartType currentType)
            {
                ChartTasks.Series.Clear();

                Series currentSeries = new Series
                {
                    Name = "Projects",
                    ChartType = currentType,
                    IsValueShownAsLabel = true
                };

                ChartTasks.Series.Add(currentSeries);

                // --- НОВАЯ ЛОГИКА: ЗАПРОС К БАЗЕ ДАННЫХ ---

                // Ищем задачи, у которых StudentId совпадает с ID выбранного студента
                var tasksFromDb = _context.StudentTasks
                                          .Where(t => t.StudentId == currentUser.Id)
                                          .ToList();

                // Если задач нет, можно вывести 0 или ничего не делать
                if (tasksFromDb.Count == 0)
                {
                    // Можно добавить пустую точку или вывести сообщение, но пока оставим пустым
                }
                else
                {
                    // Проходимся по реальным данным из таблицы
                    foreach (var task in tasksFromDb)
                    {
                        // X = Название проекта, Y = Значение (Value)
                        currentSeries.Points.AddXY(task.Title, task.Value);
                    }
                }
                // ------------------------------------------

                if (currentType == SeriesChartType.Pie)
                {
                    currentSeries["PieLabelStyle"] = "Outside";
                }

                ChartTasks.Legends[0].Enabled = true;

                // Обновляем заголовок диаграммы, чтобы было понятно, чьи данные
                ChartTasks.Titles.Clear();
                ChartTasks.Titles.Add($"Проекты студента: {currentUser.LastName}");
            }
        }
    }
}