using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using Microsoft.Office.Interop.Word;
using static System.Windows.Forms.VisualStyles.VisualStyleElement;

namespace MP2
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            var Word1 = new Microsoft.Office.Interop.Word.Application();
            var Doc1 = Word1.Documents.Add();

            Doc1.Words.First.InsertBefore(textBox1.Text);

            Doc1.CheckSpelling();

            var isp_text = Doc1.Content.Text;

            textBox1.Text = isp_text;

            Word1.Documents.Close(false);

            Word1.Application.Quit();

            Word1 = null;
        }

        private void textBox1_TextChanged(object sender, EventArgs e)
        {

        }

        private void Form1_Load(object sender, EventArgs e)
        {
            textBox1.Text = string.Empty;
            textBox1.TabIndex = 0;
            button1.TabIndex = 1;
        }

        private void button2_Click(object sender, EventArgs e)
        {
            string[] Names = { "Иванов Иван", "Петров Петр", "Сидоров Сидор", "Кузнецов Кузьма", "Васильев Василий", "Михайлов Михаил" };
            string[] Phones = { "8-999-123-45-67", "8-999-765-43-21", "8-999-111-22-33", "8-999-444-55-66", "8-999-777-88-99", "8-999-000-11-22" };

            var Word1 = new Microsoft.Office.Interop.Word.Application();

            Word1.Visible = true;
            var Doc1 = Word1.Documents.Add();

            Word1.Selection.TypeText("Таблица телефонов");
            Table table = Doc1.Tables.Add(Doc1.Range(0, 0), 7, 2);

            table.Cell(1, 1).Range.Text = "Имя";
            table.Cell(1, 2).Range.Text = "Телефон";

            for (int i = 2; i <= 7; i++)
            {
                table.Cell(i, 1).Range.Text = Names[i - 2];
                table.Cell(i, 2).Range.Text = Phones[i - 2];
            }
        }

    }
}