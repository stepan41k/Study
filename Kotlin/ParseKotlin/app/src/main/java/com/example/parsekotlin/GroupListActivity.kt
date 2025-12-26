package com.example.parsekotlin

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.ArrayAdapter
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.parsekotlin.databinding.ActivityGroupListBinding
import com.example.parsekotlin.models.GroupLink
import com.example.parsekotlin.models.Institute
import kotlinx.coroutines.*

class GroupListActivity : AppCompatActivity() {
    private lateinit var binding: ActivityGroupListBinding
    private val parser = Parser()
    private var institutes = listOf<Institute>()
    private var allGroups = listOf<GroupLink>()
    private var filteredGroups = listOf<GroupLink>()
    private val coroutineScope = CoroutineScope(Dispatchers.Main)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityGroupListBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val grade = intent.getIntExtra("grade", 1)
        supportActionBar?.title = "$grade курс"
        binding.title.text = "Группы $grade курса"

        setupUI()
        loadInstitutes(grade)
    }

    private fun setupUI() {
        val instituteAdapter = ArrayAdapter(
            this,
            android.R.layout.simple_spinner_item,
            mutableListOf("Все институты")
        )
        instituteAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        binding.instituteSpinner.adapter = instituteAdapter

        binding.instituteSpinner.onItemSelectedListener =
            object : android.widget.AdapterView.OnItemSelectedListener {
                override fun onItemSelected(
                    parent: android.widget.AdapterView<*>,
                    view: android.view.View?,
                    position: Int,
                    id: Long
                ) {
                    if (position == 0) {
                        showAllGroups()
                    } else {
                        val institute = institutes[position - 1]
                        filterGroupsByInstitute(institute.name)
                    }
                }

                override fun onNothingSelected(parent: android.widget.AdapterView<*>) {
                    showAllGroups()
                }
            }

        binding.groupsList.setOnItemClickListener { _, _, position, _ ->
            if (filteredGroups.isNotEmpty() && position < filteredGroups.size) {
                val selectedGroup = filteredGroups[position]
                openScheduleActivity(selectedGroup)
            }
        }

        binding.retryButton.setOnClickListener {
            val grade = intent.getIntExtra("grade", 1)
            loadInstitutes(grade)
        }
    }

    private fun loadInstitutes(grade: Int) {
        coroutineScope.launch {
            try {
                binding.progressBar.visibility = android.view.View.VISIBLE
                binding.contentLayout.visibility = android.view.View.GONE
                binding.errorText.visibility = android.view.View.GONE

                val loadedInstitutes = withContext(Dispatchers.IO) {
                    parser.fetchInstitutesByCourse(grade)
                }

                if (loadedInstitutes.isEmpty()) {
                    showError("Нет данных для $grade курса\nПопробуйте выбрать другой курс")
                    return@launch
                }

                institutes = loadedInstitutes
                allGroups = institutes.flatMap { it.groups }
                filteredGroups = allGroups

                updateUI()

                Toast.makeText(
                    this@GroupListActivity,
                    "Загружено ${allGroups.size} групп из ${institutes.size} институтов",
                    Toast.LENGTH_SHORT
                ).show()

            } catch (e: Exception) {
                showError("Ошибка загрузки данных: ${e.message}\nПроверьте подключение к интернету")
                e.printStackTrace()
            } finally {
                binding.progressBar.visibility = android.view.View.GONE
            }
        }
    }

    private fun updateUI() {
        val instituteNames = mutableListOf("Все институты")
        instituteNames.addAll(institutes.map { it.name })

        val instituteAdapter = ArrayAdapter(
            this,
            android.R.layout.simple_spinner_item,
            instituteNames
        )
        instituteAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        binding.instituteSpinner.adapter = instituteAdapter

        showAllGroups()
        binding.contentLayout.visibility = android.view.View.VISIBLE
        binding.errorText.visibility = android.view.View.GONE
    }

    private fun showAllGroups() {
        filteredGroups = allGroups
        updateGroupsList()
        binding.filterInfo.text = "Все группы (${allGroups.size})"
    }

    private fun filterGroupsByInstitute(instituteName: String) {
        val institute = institutes.find { it.name == instituteName }
        if (institute != null) {
            filteredGroups = institute.groups
            updateGroupsList()
            binding.filterInfo.text = "${institute.name} (${institute.groups.size} групп)"
        }
    }

    private fun updateGroupsList() {
        val adapter = GroupAdapter(this, filteredGroups.map { it.name })
        binding.groupsList.adapter = adapter
        binding.groupsCount.text = "Найдено групп: ${filteredGroups.size}"
    }

    class GroupAdapter(
        private val context: android.content.Context,
        private val groups: List<String>
    ) : android.widget.ArrayAdapter<String>(context, R.layout.item_group, groups) {
        override fun getView(position: Int, convertView: android.view.View?, parent: android.view.ViewGroup): android.view.View {
            val view = convertView ?: android.view.LayoutInflater.from(context)
                .inflate(R.layout.item_group, parent, false)
            val groupName = view.findViewById<android.widget.TextView>(R.id.groupName)
            groupName.text = groups[position]
            return view
        }
    }

    private fun openScheduleActivity(group: GroupLink) {
        val prefs = getSharedPreferences("last_group", Context.MODE_PRIVATE).edit()
        prefs.putString("name", group.name)
        prefs.putString("url", group.href)
        prefs.apply()

        val updateIntent = Intent(this, AppWidget::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        }

        val ids = AppWidgetManager.getInstance(this).getAppWidgetIds(
            ComponentName(this, AppWidget::class.java)
        )
        updateIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        sendBroadcast(updateIntent)

        val intent = Intent(this, ScheduleActivity::class.java)
        intent.putExtra("groupName", group.name)
        intent.putExtra("groupUrl", group.href)
        startActivity(intent)
    }


    private fun showError(message: String) {
        binding.errorText.text = message
        binding.errorText.visibility = android.view.View.VISIBLE
        binding.contentLayout.visibility = android.view.View.GONE
        binding.retryButton.visibility = android.view.View.VISIBLE
    }

    override fun onDestroy() {
        super.onDestroy()
        coroutineScope.cancel()
    }
}
