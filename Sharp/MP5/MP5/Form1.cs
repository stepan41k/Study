using Npgsql;
using System;
using System.Collections;
using System.Data;
using System.Data.Common;
using System.Windows.Forms;

namespace MP5
{
    public partial class Form1 : Form
    {
        private readonly string ConnectionString = "Host=5942e-rw.db.pub.dbaas.postgrespro.ru;Port=5432;Username=raspopov_si;Password=h#Lv7S6@%Y#3d;Database=dbstud;";

        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {

            LoadDataFromView("authors_and_books");
        }

        private void view1Button_Click(object sender, EventArgs e)
        {
            LoadDataFromView("authors_and_books");
        }

        private void view2Button_Click(object sender, EventArgs e)
        {
            LoadDataFromView("books_and_publichers");
        }

        private void view3Button_Click(object sender, EventArgs e)
        {
            LoadDataFromView("author_book_count");
        }

        /// <summary>
        /// Метод для загрузки, отображения данных из указанного представления и обновления счётчика.
        /// </summary>
        /// <param name="viewName">Имя таблицы или представления для загрузки.</param>
        private void LoadDataFromView(string viewName)
        {
            ArrayList records = new ArrayList();

            try
            {
                using (NpgsqlConnection con = new NpgsqlConnection(ConnectionString))
                {
                    string sqlQuery = $"SELECT * FROM {viewName}";
                    using (NpgsqlCommand cmd = new NpgsqlCommand(sqlQuery, con))
                    {
                        cmd.CommandType = CommandType.Text;

                        con.Open();

                        using (NpgsqlDataReader rdr = cmd.ExecuteReader())
                        {
                            if (rdr.HasRows)
                            {
                                foreach (DbDataRecord rec in rdr)
                                {
                                    records.Add(rec);
                                }
                            }
                        }
                    }
                } 
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка при загрузке данных: {ex.Message}", "Ошибка", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }

            dataGridView1.DataSource = null; // Очищаем предыдущий источник данных
            dataGridView1.DataSource = records;

            // В статусную строку поместить текст
            lbRecordsCount.Text = $"Количество записей в таблице = {records.Count}";
        }


        // 4.6. Реализация пункта меню "Файл" -> "Выход"
        private void exitMenuItem_Click(object sender, EventArgs e)
        {
            Application.Exit();
        }

        private void dataGridView1_CellContentClick(object sender, DataGridViewCellEventArgs e)
        {

        }

        private void выходToolStripMenuItem_Click(object sender, EventArgs e)
        {
            Application.Exit();
        }
    }
}