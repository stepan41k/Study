package com.example.parsekotlin

import android.content.Intent
import android.os.Bundle
import android.widget.ArrayAdapter
import androidx.appcompat.app.AppCompatActivity
import com.example.parsekotlin.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val courses = listOf("1 курс", "2 курс", "3 курс", "4 курс", "5 курс", "6 курс")
        binding.courseList.adapter = ArrayAdapter(
            this,
            R.layout.item_course,
            R.id.courseTitle,
            courses
        )

        binding.courseList.setOnItemClickListener { _, _, position, _ ->
            val grade = position + 1
            val intent = Intent(this, GroupListActivity::class.java)
            intent.putExtra("grade", grade)
            startActivity(intent)
        }
    }
}
