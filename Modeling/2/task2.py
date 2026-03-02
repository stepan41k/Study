import math

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

N = 100000
q = 10

count = 4
x = [-22, -9, -6, 21]
p = [0.5, 0.2, 0.1, 0.2]

r = np.random.rand(N)

k = [0] * count
for i in range(N):
    if 0 <= r[i] < p[0]:
        k[0] += 1
    elif p[0] <= r[i] < p[0] + p[1]:
        k[1] += 1
    elif p[0] + p[1] <= r[i] < p[0] + p[1] + p[2]:
        k[2] += 1
    elif p[0] + p[1] + p[2] <= r[i] < p[0] + p[1] + p[2] + p[3]:
        k[3] += 1

Mx = sum([x[i] * p[i] for i in range(count)])
Dx = sum([(x[i] ** 2) * p[i] for i in range(count)]) - Mx**2

m = 1 / N * sum([k[i] * x[i] for i in range(count)])
g = 1 / N * sum([k[i] * (x[i] ** 2) for i in range(count)]) - m**2

df1 = pd.DataFrame(
    [[N, Mx, m, abs(Mx - m), Dx, g, abs(Dx - g)]],
    columns=["N", "Mx", "m", "|Mx-m|", "Dx", "g", "|Dx-g|"],
)

df2 = pd.DataFrame([k], columns=[f"k{i}" for i in range(count)])

fig, ax = plt.subplots(figsize=(10, 4))
ax.axis("off")

table1 = ax.table(
    cellText=df1.round(6).values,
    colLabels=df1.columns,
    loc="upper center",
    cellLoc="center",
)
table1.auto_set_font_size(False)
table1.set_fontsize(10)
table1.scale(1.2, 1.5)

table2 = ax.table(
    cellText=df2.values, colLabels=df2.columns, loc="lower center", cellLoc="center"
)
table2.auto_set_font_size(False)
table2.set_fontsize(10)
table2.scale(1.2, 1.5)

ax.set_title("Результаты моделирования и частоты k", fontweight="bold")
plt.show()
