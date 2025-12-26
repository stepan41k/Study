using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace MP2C
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

        private void label1_Click(object sender, EventArgs e)
        {

        }

        private void button1_Click(object sender, EventArgs e)
        {
            int i;
            if (int.TryParse(textBox1.Text, out i)) {
                int k = 1, r, S = 0, P = 1;
                int X = Convert.ToInt32(i);
                while (X != 0)
                {
                    r = X % 10;
                    X /= 10;
                    S += r;
                    P *= r;
                    k++;
                }

                textBox3.Text = Convert.ToString(S);
                textBox2.Text = Convert.ToString(P);
            }
            else
            {
                textBox2.Text = "Введите число!";
                textBox3.Text = "Введите число!";
            }   
        }

        private void textBox1_TextChanged(object sender, EventArgs e)
        {

        }

        private void textBox3_TextChanged(object sender, EventArgs e)
        {

        }

        private void textBox2_TextChanged(object sender, EventArgs e)
        {

        }
    }
}
