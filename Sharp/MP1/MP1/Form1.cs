using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace MP1
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {

        }

        private void radioButton1_CheckedChanged(object sender, EventArgs e)
        {
            int i;
            if (int.TryParse(textBox1.Text, out i))
            {
                textBox2.Text = "В 2-ой системе = " + Convert.ToString(i, 2);
            } else {
                textBox2.Text = "Невалидное значение! Введите число!";
            }

            radioButton1.Checked = false;
        }

        private void radioButton2_CheckedChanged(object sender, EventArgs e)
        {
            int i;
            if (int.TryParse(textBox1.Text, out i))
            {
                textBox2.Text = "В 16-ой системе = " + Convert.ToString(i, 16);
            }
            else
            {
                textBox2.Text = "Невалидное значение! Введите число!";
            }

            radioButton2.Checked = false;
        }

        private void radioButton3_CheckedChanged(object sender, EventArgs e)
        {
            int i;
            if (int.TryParse(textBox1.Text, out i))
            {
                textBox2.Text = "В 8-ой системе = " + Convert.ToString(i, 8);
            }
            else
            {
                textBox2.Text = "Невалидное значение! Введите число!";
            }

            radioButton3.Checked = false;
        }

        private void textBox2_TextChanged(object sender, EventArgs e)
        {

        }
    }
}
