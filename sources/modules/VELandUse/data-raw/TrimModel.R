
#' Trim Model Objects Using Predefined Rules
TrimModel <- function(model) {
    if ("zeroinfl" %in% class(model)) {
        model$model <- NULL
        model$na.action <- NULL
        environment(model$formula) <- baseenv()
        environment(model$terms$full) <- baseenv()
        environment(model$terms$zero) <- baseenv()
        environment(model$terms$count) <- baseenv()
    }

    if ("hurdle" %in% class(model)) {
        model$model <- NULL
        model$residuals <- NULL
        model$fitted.values <- NULL
        model$weights <- NULL
        model$y <- NULL
        environment(model$formula) <- baseenv()
        environment(model$terms$full) <- baseenv()
        environment(model$terms$zero) <- baseenv()
        environment(model$terms$count) <- baseenv()
    }

    if ("polr" %in% class(model)) {
        model$model <- NULL
        environment(model$terms) <- baseenv()
        model$fitted.values <- 0.0
        model$na.action <- NULL
        model$lp <- NULL
        # model$qr$qr <- NULL
    }

    if ("lm" %in% class(model)) {
        model$model <- NULL
        environment(model$terms) <- baseenv()
        model$na.action <- NULL
        model$effects <- NULL
        model$fitted.values <- NULL
        model$residuals <- NULL
        model$qr$qr <- NULL
    }

    if ("mlogit" %in% class(model)) {
        model$gradient <- NULL
        model$fitted.values <- NULL
        model$probabilities <- NULL
        model$linpred <- NULL
        model$residuals <- NULL
        model$hessian <- NULL
        model$est.stat <- NULL
        model$omega <- NULL
        model$freq <- NULL
        model$model <- NULL
    }

    if ("rpart" %in% class(model)) {
        model$where <- NULL
        model$y <- NULL
    }

    model
}
