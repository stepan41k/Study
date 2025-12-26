using MP8;
using MP8.Models;
using System.Collections.ObjectModel;
using System.Linq;
using System.Windows;

namespace MP8
{
    public partial class MainWindow : Window
    {
        // ... (код, который уже был, остается без изменений)
        public ObservableCollection<Student> Students { get; set; }

        public MainWindow()
        {
            InitializeComponent();
            Students = new ObservableCollection<Student>();
            StudentsDataGrid.ItemsSource = Students;
            LoadStudents();
        }

        private void LoadStudents()
        {
            // ... (метод LoadStudents остается без изменений)
            Students.Clear();
            using (var context = new DatabaseContext())
            {
                var studentsList = context.Students.ToList();
                foreach (var student in studentsList)
                {
                    Students.Add(student);
                }
            }
        }

        private void AddStudent_Click(object sender, RoutedEventArgs e)
        {
            // ... (метод добавления остается без изменений)
            var addWindow = new AddStudentWindow();
            if (addWindow.ShowDialog() == true)
            {
                LoadStudents();
            }
        }

        // ОБНОВЛЕННЫЙ МЕТОД УДАЛЕНИЯ
        private void DeleteStudent_Click(object sender, RoutedEventArgs e)
        {
            // Получаем выделенного студента из таблицы
            var selectedStudent = StudentsDataGrid.SelectedItem as Student;

            if (selectedStudent == null)
            {
                MessageBox.Show("Пожалуйста, выберите студента для удаления.", "Внимание", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            // Создаем окно удаления и передаем в него выбранного студента
            var deleteWindow = new DeleteStudentWindow(selectedStudent);
            if (deleteWindow.ShowDialog() == true)
            {
                // Если удаление прошло успешно, обновляем список
                LoadStudents();
            }
        }

        // ОБНОВЛЕННЫЙ МЕТОД РЕДАКТИРОВАНИЯ
        private void EditStudent_Click(object sender, RoutedEventArgs e)
        {
            // Получаем выделенного студента
            var selectedStudent = StudentsDataGrid.SelectedItem as Student;

            if (selectedStudent == null)
            {
                MessageBox.Show("Пожалуйста, выберите студента для редактирования.", "Внимание", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            // Создаем окно редактирования и передаем в него студента
            var editWindow = new EditStudentWindow(selectedStudent);
            if (editWindow.ShowDialog() == true)
            {
                // Если сохранение прошло успешно, обновляем список
                LoadStudents();
            }
        }

        private void OpenSearch_Click(object sender, RoutedEventArgs e)
        {
            // Создаем контейнерное окно, так как StudentSearch является Page, а не Window
            Window searchHost = new Window
            {
                Title = "Поиск и фильтрация студентов",
                Content = new StudentSearch(), // Создаем экземпляр нашей страницы
                Height = 500,
                Width = 850,
                WindowStartupLocation = WindowStartupLocation.CenterScreen
            };

            // Открываем окно (Show, а не ShowDialog, чтобы можно было работать параллельно, 
            // или используйте ShowDialog(), если хотите блокировать главное окно)
            searchHost.Show();
        }
    }
}