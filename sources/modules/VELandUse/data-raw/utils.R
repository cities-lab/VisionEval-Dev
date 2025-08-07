#' trim from model object objects with large memory/space footprint and unnecessary for
#' model prediction (predict(model, data) call)
#' @param model a R model object
#' @return a trimmed model object with information unnecessary for `predict()` call stripped
#'
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

    model
}