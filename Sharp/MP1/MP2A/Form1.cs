using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using static System.Windows.Forms.VisualStyles.VisualStyleElement.Rebar;

namespace MP2A
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            int n = Convert.ToInt32(textBox1.Text); 
            int m = Convert.ToInt32(textBox2.Text); 

            int counter = 0;

            double sumConditional = 0.0;

            int conditionValue = 1;

            double arithmeticMean;

            int[,] array = new int[n, m];
            Random random = new Random();

            dataGridView1.AutoGenerateColumns = false;
            dataGridView1.AllowUserToAddRows = false;

            dataGridView1.RowCount = n;
            dataGridView1.ColumnCount = m;
            

            

            for (int i = 0; i < n; i++)
            {
                for (int j = 0; j < m; j++)
                {
                    array[i, j] = random.Next(-300, 101);

                    dataGridView1.Rows[i].Cells[j].Value = array[i, j];
                    dataGridView1.Columns[j].Width = 50;

                    if (array[i, j] > conditionValue)
                    {
                        sumConditional += array[i, j];
                        counter++;
                        dataGridView1.Rows[i].Cells[j].Style.BackColor = Color.LightGreen;
                    }
                    else
                    {
                        dataGridView1.Rows[i].Cells[j].Style.BackColor = Color.White;
                    }
                }
            }



            if (counter > 0)
            {
                arithmeticMean = sumConditional / counter;
                label3.Text = $"Среднее арифметическое элементов > {conditionValue}: {arithmeticMean:F2}";
                label3.ForeColor = Color.DarkGreen;
            }
            else
            {
                arithmeticMean = 0;
                label3.Text = $"Нет элементов, удовлетворяющих условию (>{conditionValue}). Среднее = 0.";
                label3.ForeColor = Color.Red;
           }
        }

        private void textBox1_TextChanged(object sender, EventArgs e)
        {

        }

        private void textBox2_TextChanged(object sender, EventArgs e)
        {

        }

        private void dataGridView1_CellContentClick(object sender, DataGridViewCellEventArgs e)
        {

        }

        private void label3_Click(object sender, EventArgs e)
        {

        }
    }
}
