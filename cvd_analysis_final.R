# =============================================================
# Cardiovascular Risk Modelling - Cleveland Heart Disease Cohort
# Author: Kunal Patil
# Final version
# =============================================================

library(tidyverse)
library(pROC)
library(broom)

# ---- 1. Load data ----
data <- read.csv("heart_disease.csv")
cat("Dataset:", nrow(data), "patients,", ncol(data), "variables\n")
cat("Disease prevalence:", round(mean(data$condition)*100, 1), "%\n\n")

# ---- 2. Descriptive statistics ----
print(summary(data[, c("age", "trestbps", "chol", "thalach")]))
print(table(Sex = data$sex, Condition = data$condition))

# ---- 3. Univariate group comparisons ----
t_age <- t.test(age ~ condition, data = data)
chi_sex <- chisq.test(table(data$sex, data$condition))
cat("\nT-test (age by condition): p =", signif(t_age$p.value, 3), "\n")
cat("Chi-square (sex vs condition): p =", signif(chi_sex$p.value, 3), "\n\n")

# ---- 4. Logistic regression model ----
model <- glm(condition ~ age + sex + trestbps + chol + thalach,
             data = data, family = binomial)
print(summary(model))

# ---- 5. Odds ratios + 95% confidence intervals ----
results <- tidy(model, exponentiate = TRUE, conf.int = TRUE) %>%
  select(term, OR = estimate, CI_low = conf.low, CI_high = conf.high, p.value) %>%
  mutate(Significant = p.value < 0.05) %>%
  mutate(across(where(is.numeric), round, 4))
print(results)

# ---- 6. AUC + ROC curve ----
probs <- predict(model, type = "response")
roc_obj <- roc(data$condition, probs, quiet = TRUE)
auc_val <- auc(roc_obj)
cat("\nAUC (in-sample):", round(auc_val, 3), "\n")
cat("Honest note: in-sample AUC is optimistic. Next step: k-fold CV.\n")

plot(roc_obj,
     main = paste0("ROC Curve - CVD Prediction (AUC = ", round(auc_val, 3), ")"),
     col = "steelblue", lwd = 2.5, print.auc = TRUE)
abline(a = 0, b = 1, col = "gray", lty = 2)

# ---- 7. Confusion matrix at threshold 0.5 ----
pred <- ifelse(probs >= 0.5, 1, 0)
cm <- table(Actual = data$condition, Predicted = pred)
print(cm)

sens <- cm[2,2] / sum(cm[2, ])
spec <- cm[1,1] / sum(cm[1, ])
acc  <- sum(diag(cm)) / sum(cm)
cat(sprintf("\nAccuracy = %.3f | Sensitivity = %.3f | Specificity = %.3f\n",
            acc, sens, spec))
